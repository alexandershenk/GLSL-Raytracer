#include "shader.h"

Shader::Shader(const std::string& shaderFilePath, 
		GLuint program, GLenum shaderType){

	//Load from file
	std::ifstream shaderFile(shaderFilePath);

	std::stringstream shaderSourceStream;
	shaderSourceStream << shaderFile.rdbuf();

	std::string shaderSrcString = shaderSourceStream.str();
	const char* shaderSrc = shaderSrcString.c_str();

	// setup a shader
	GLuint shader = glCreateShader(shaderType);

	glShaderSource(shader, 1, &shaderSrc, nullptr);
	glCompileShader(shader);

	glAttachShader(program, shader);
	glLinkProgram(program);

	int rvalue;
    glGetProgramiv(program, GL_LINK_STATUS, &rvalue);
    if (!rvalue) {
        fprintf(stderr, "Error in linking compute shader program\n");
        GLchar log[10240];
        GLsizei length;
        glGetProgramInfoLog(program, 10239, &length, log);
        fprintf(stderr, "Linker log:\n%s\n", log);
		std::exit(41);
    }   
	glValidateProgram(program);

	glDeleteShader(shader);
}
