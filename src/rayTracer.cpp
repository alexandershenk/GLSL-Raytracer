#include "programs.h"
#include "shader.h"
#include <iostream>

#define GLM_FORCE_SWIZZLE
#include <glm/glm.hpp> 
#include <glm/gtc/matrix_transform.hpp> 
#include <glm/gtc/type_ptr.hpp> 

struct camData{
	glm::vec4 camPos = glm::vec4(15.0f, 0.5, 0.0f, 1.0f);

	glm::mat4 view = glm::lookAt(camPos.xyz(),
	glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 1.0f, 0.0f)); //Cam is 1.63 units in the air, 10 units away from origin, looking at the origin
	glm::mat4 proj = glm::perspective( glm::radians(45.0f), 1.0f/1, 0.1f, 10.0f); //May nned to fix aspect ratio

} camData;


glm::mat4 trans1 = (glm::transpose(glm::mat4(1.0, 0.0, 0.0, 2.0, 
   							  0.0, 1.0, 0.0, 0.5, 
   							  0.0, 0.0, 1.0,  0.0,  
   							  0.0, 0.0, 0.0,  1.0)));

glm::mat4 trans2 = (glm::transpose(glm::mat4(1.0, 0.0, 0.0, 0, 
   							  0.0, 1.0, 0.0, 0.5, 
   							  0.0, 0.0, 1.0,  0.0,  
   							  0.0, 0.0, 0.0,  1.0)));

glm::mat4 trans3 = (glm::transpose(glm::mat4(1.0, 0.0, 0.0, 0.0, 
   							  0.0, 1.0, 0.0, -1.0, 
   							  0.0, 0.0, 1.0,  0.0,  
   							  0.0, 0.0, 0.0,  1.0)));

glm::mat4 trans4 = (glm::transpose(glm::mat4(1.0, 0.0, 0.0, 0.0, 
   							  0.0, 1.0, 0.0, 0.5, 
   							  0.0, 0.0, 1.0,  2.0,  
   							  0.0, 0.0, 0.0,  1.0)));

glm::mat4 trans5 = (glm::transpose(glm::mat4(1.0, 0.0, 0.0, 0.0, 
							    0.0, 1.0, 0.0, 0.5, 
							    0.0, 0.0, 1.0,  -2.0,  
							    0.0, 0.0, 0.0,  1.0)));

struct object{
	// TODO: Refraction, texture
	glm::vec4 color;
	float reflectivity;
	float specularity;

	int type;
	float p1;
	glm::mat4 trans;
} objects[5];

GLuint genScreen(){
	GLuint texHandle;
	glGenTextures(1, &texHandle);

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texHandle);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, COMP_SIZE, COMP_SIZE, 0, GL_RGBA, GL_FLOAT, NULL);


	// Because we're also using this tex as an image (in order to write to it),
	// we bind it to an image unit as well
	glBindImageTexture(0, texHandle, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
	return texHandle;
}

GLuint genRayTracerProg(){
	for(int i=0; i<4;i++){
		for(int j=0; j<4;j++){
			std::cout << camData.view[i][j] << std::endl;
			std::cout << camData.proj[i][j] << std::endl;

		}
	}
	

	// Define some structs
	objects[0].type =1;
	objects[0].trans =trans1;
	objects[0].color = glm::vec4(0,0,1,1);
	objects[0].reflectivity = 1;
	objects[0].specularity = 1;

	objects[1].type =1;
	objects[1].trans =trans2;
	objects[1].color = glm::vec4(0,0,1,1);
	objects[1].reflectivity = 1;
	objects[1].specularity = 0;

	objects[2].type =2;
	objects[2].trans =trans3;
	objects[2].color = glm::vec4(1,0,0,1);
	objects[2].reflectivity = 1;
	objects[2].specularity = 1;

	objects[3].type =1;
	objects[3].trans =trans4;
	objects[3].color = glm::vec4(0,0,1,1);
	objects[3].reflectivity = 1;
	objects[3].specularity = 1;

	objects[4].type =1;
	objects[4].trans =trans5;
	objects[4].color = glm::vec4(0,0,1,1);
	objects[4].reflectivity = 1;
	objects[4].specularity = 0;


	GLuint progHandle = glCreateProgram();
	Shader compShader("shaders/comp.glsl", progHandle, GL_COMPUTE_SHADER);

	// Initialize program
	glUseProgram(progHandle);

	glUniform1i(glGetUniformLocation(progHandle, "destTex"), 0);

	// Cam buffer
	GLuint camDataBindingPoint = 1;
	GLuint camDataBuffer;
	GLuint camIndex = glGetUniformBlockIndex(progHandle, "camData");
	glUniformBlockBinding(progHandle, camIndex, camDataBindingPoint);

	glGenBuffers(1, &camDataBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, camDataBuffer);
	glBufferData(GL_UNIFORM_BUFFER, sizeof(camData), &camData, GL_DYNAMIC_DRAW);

	glBindBufferBase(GL_UNIFORM_BUFFER, camDataBindingPoint, camDataBuffer);

	// Objects SSBO
	GLuint objDataBindingPoint = 3;
	GLuint objDataBuffer;
	glUniformBlockBinding(progHandle, 3, objDataBindingPoint);

	glGenBuffers(1, &objDataBuffer);
	glBindBuffer(GL_SHADER_STORAGE_BUFFER, objDataBuffer);
	glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(objects), &objects, GL_STATIC_DRAW);

	glBindBufferBase(GL_SHADER_STORAGE_BUFFER, objDataBindingPoint, objDataBuffer);


	return progHandle;

}

