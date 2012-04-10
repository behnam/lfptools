#include <cstdio>
#include <cstdlib>

#include <GLUT/glut.h>

#include "stb_image.c"

void
display()
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

void
keyboard(unsigned char key, int x, int y)
{
    switch (key) {
    case 'q':
        exit(0);
        break; 
    default:
        break; 
    }
}
    

int
main(
    int argc,
    char **argv)
{
    glutInit(&argc, argv);
    glutInitWindowSize(512, 512);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGBA);

    glutCreateWindow("lfp view");
    glutDisplayFunc(display);
    glutKeyboardFunc(keyboard);
    glutMainLoop();

    return 0;
}
