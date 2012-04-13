#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <float.h>

#include <GLUT/glut.h>

#include "stb_image.c"

#include "trackball.h"

#define MAX_NUM_LAYERS  (12)
#define DEPTH_MAP_SIZE  (20)

static GLuint gTexIDs[MAX_NUM_LAYERS];
static int   gNumLayers;
static float gDepthmap[DEPTH_MAP_SIZE][DEPTH_MAP_SIZE];
static float depth_max, depth_min;

static int mouse_x, mouse_y;
static int mouse_m_pressed;
static int mouse_moving;
static int width = 512, height = 512;
static float view_org[3], view_tgt[3];
static float curr_quat[4], prev_quat[4];
static int curr_layer = 0;

static unsigned char*
load_image(
    const char* filename,
    int* x,
    int* y,
    int* comp,
    int  req_comp)
{
    return (unsigned char*)stbi_load(filename, x, y, comp, req_comp);
}

static float*
load_depth(
    const char* filename)
{
    char buf[4096];
    sprintf(buf, "%s_depth.txt", filename);
    FILE* fp = fopen(buf, "r");

    depth_max = -FLT_MAX;
    depth_min =  FLT_MAX;

    int x, y;
    for (y = 0; y < DEPTH_MAP_SIZE; y++) {
        for (x = 0; x < DEPTH_MAP_SIZE; x++) {
            fscanf(fp, "%f\n", &gDepthmap[y][x]);
            if (depth_min > gDepthmap[y][x]) depth_min = gDepthmap[y][x];
            if (depth_max < gDepthmap[y][x]) depth_max = gDepthmap[y][x];
        }
    }

    fclose(fp);

    printf("depth [%f - %f]\n", depth_min, depth_max);
}

static void
setup_textures(
    const char *filename)
{
    int i;

    int w, h;
    int comp;
    int req_comp = 3; // RGB

    assert(gNumLayers < MAX_NUM_LAYERS);

    glGenTextures(gNumLayers, gTexIDs);

    for (i = 0; i < gNumLayers; i++) {
        char buf[4096];
        sprintf(buf, "%s_%02d.jpg", filename, i);
        unsigned char* img = load_image(buf, &w, &h, &comp, req_comp);
        if (!img) {
            fprintf(stderr, "Can't read image %s\n", buf);
            exit(1);
        }
        printf("Loaded %s.\n", buf);

        glBindTexture(GL_TEXTURE_2D, gTexIDs[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        glTexImage2D(GL_TEXTURE_2D, 0, 3, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, img);

    }
    glEnable(GL_TEXTURE_2D);
}

//
// --
//

static void
reshape(int w, int h)
{
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45.0, (float)w / (float)h, 0.1f, 10.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    width = w; height = h;
}

static void
draw_mesh()
{
    int x, y;
    float w = 1.0 / (DEPTH_MAP_SIZE-1);
    float dw = 1.0 / (depth_max - depth_min);
    float ds = depth_min;

    glBegin(GL_QUADS);
    for (y = 0; y < DEPTH_MAP_SIZE-1; y++) {
        int yy = DEPTH_MAP_SIZE-1-y;
        for (x = 0; x < DEPTH_MAP_SIZE-1; x++) {
            glTexCoord2f((x + 0) * w, 1.0 - (y+0) * w); 
            glVertex3d(2.0*(x+0)*w - 1.0, 2.0*(y+0)*w - 1.0, -dw*(gDepthmap[yy+0][x+0]-ds));
            glTexCoord2f((x + 0) * w, 1.0 - (y+1) * w); 
            glVertex3d(2.0*(x+0)*w - 1.0, 2.0*(y+1)*w - 1.0, -dw*(gDepthmap[yy-1][x+0]-ds));
            glTexCoord2f((x + 1) * w, 1.0 - (y+1) * w); 
            glVertex3d(2.0*(x+1)*w - 1.0, 2.0*(y+1)*w - 1.0, -dw*(gDepthmap[yy-1][x+1]-ds));
            glTexCoord2f((x + 1) * w, 1.0 - (y+0) * w); 
            glVertex3d(2.0*(x+1)*w - 1.0, 2.0*(y+0)*w - 1.0, -dw*(gDepthmap[yy+0][x+1]-ds));
        }
    }
    glEnd();
}


static void
display()
{
    GLfloat mat[4][4];

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // camera & rotate
    gluLookAt(view_org[0], view_org[1], view_org[2],
          view_tgt[0], view_tgt[1], view_tgt[2],
          0.0, 1.0, 0.0);

    build_rotmatrix(mat, curr_quat);
    glMultMatrixf(&mat[0][0]);

    glBindTexture(GL_TEXTURE_2D, gTexIDs[curr_layer]);

    draw_mesh();

    //glBegin(GL_POLYGON);
    //    glTexCoord2f(0 , 0); glVertex2f(-0.9 , -0.9);
    //    glTexCoord2f(0 , 1); glVertex2f(-0.9 , 0.9);
    //    glTexCoord2f(1 , 1); glVertex2f(0.9 , 0.9);
    //    glTexCoord2f(1 , 0); glVertex2f(0.9 , -0.9);
    //glEnd();

    glutSwapBuffers();
}

static void
keyboard(unsigned char key, int x, int y)
{
    switch (key) {
    case 'q':
    case 27:
        exit(0);
        break; 
    case 'j':
        curr_layer--;
        if (curr_layer < 0) curr_layer = 0;
        printf("layer %d\n", curr_layer);
        break;
    case 'k':
        curr_layer++;
        if (curr_layer >= gNumLayers) curr_layer = gNumLayers-1;
        printf("layer %d\n", curr_layer);
        break;
    default:
        break; 
    }

    glutPostRedisplay();
}

static void
mouse(int button, int state, int x, int y)
{
    int mod = glutGetModifiers();

    if (button == GLUT_LEFT_BUTTON && state == GLUT_DOWN) {
        if (mod == GLUT_ACTIVE_SHIFT) {
            mouse_m_pressed = 1;
        } else {
            trackball(prev_quat, 0, 0, 0, 0);
        }
        mouse_moving = 1;
        mouse_x = x;
        mouse_y = y;
    } else if (button == GLUT_LEFT_BUTTON && state == GLUT_UP) {
        mouse_m_pressed = 0;
        mouse_moving = 0;
    }
 
}
    
static void
motion(int x, int y)
{
    float w = 1.0;
    float mw = 0.1;

    if (mouse_moving) {
        if (mouse_m_pressed) {
            view_org[0] += mw * (mouse_x - x);
            view_org[1] -= mw * (mouse_y - y);
            view_tgt[0] += mw * (mouse_x - x);
            view_tgt[1] -= mw * (mouse_y - y);
        } else {
            trackball(prev_quat,
                  w * (2.0 * mouse_x - width)  / width,
                  w * (height - 2.0 * mouse_y) / height,
                  w * (2.0 * x - width)  / width,
                  w * (height - 2.0 * y) / height);
            add_quats(prev_quat, curr_quat, curr_quat);
        }

        mouse_x = x;
        mouse_y = y;
        
    }

    glutPostRedisplay();
}

static void
init()
{
    trackball(curr_quat, 0, 0, 0, 0);

    view_org[0] = 0.0f;
    view_org[1] = 0.0f;
    view_org[2] = 3.0f;

    view_tgt[0] = 0.0f;
    view_tgt[1] = 0.0f;
    view_tgt[2] = 0.0f;
}

int
main(
    int argc,
    char **argv)
{
    const char *input = "input.jpg";

    if (argc < 3) {
        printf("Usage: lfpview basefilename N\n");
        printf("  basefilename_00.jpg, basefilename_01.jpg, ... basefilename_N.jpg and basename_depth.txt will be loaded.\n");
        exit(1);
    }

    input = argv[1];
    gNumLayers = atoi(argv[2]);

    glutInit(&argc, argv);
    glutInitWindowSize(512, 512);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGBA);

    init();

    glutCreateWindow("lfp view");

    setup_textures(input);
    load_depth(input);

    glutReshapeFunc(reshape);
    glutDisplayFunc(display);
    glutKeyboardFunc(keyboard);
    glutMouseFunc(mouse);
    glutMotionFunc(motion);
    glutMainLoop();

    return 0;
}
