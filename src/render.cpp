#include "programs.h"
#include "shader.h"
#include <iostream>

//GLuint genRenderProg(GLuint texHandle){
GLuint genRenderProg(){
	
	GLuint progHandle = glCreateProgram();

	Shader vertShader("shaders/vert.glsl", 
			progHandle, GL_VERTEX_SHADER);
	Shader fragmentShader("shaders/frag.glsl", 
			progHandle, GL_FRAGMENT_SHADER);

	// Initialize program
	glUseProgram(progHandle);

	//associate our texture with srcTex input var in the shader
	glUniform1i(glGetUniformLocation(progHandle, "srcTex"),  0);

	GLuint vertArray;
	glGenVertexArrays(1, &vertArray);
	glBindVertexArray(vertArray);

	//load our position data into a buffer, set it to an attrib array
	GLuint posBuf;
	glGenBuffers(1, &posBuf);
	glBindBuffer(GL_ARRAY_BUFFER, posBuf);

	float data[] = {
		-1.0f, -1.0f,

		-1.0f, 1.0f,
		1.0f, -1.0f,
		1.0f, 1.0f
	};

	glBufferData(GL_ARRAY_BUFFER, sizeof(float)*8, data, GL_STREAM_DRAW);
	GLint posPtr  = glGetAttribLocation(progHandle, "pos");

	glVertexAttribPointer(posPtr, 2, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(posPtr);

	return progHandle;
}

/*
void initRenderProg(){
	glUseProgram(progHandle);

}
*/
