#version 430

/* TODO:
quadratic function DRYness
*/

precision highp float;
precision highp int;

uniform float roll;

// What this shader will write to
layout(rgba32f, binding = 0) uniform image2D destTex;

layout(std140, binding = 2) uniform camData
{
	vec4 cPos;
	mat4 view;
	mat4 proj;
};

mat4 invViewProjMat; 

// border rays used in interpolation to current ray
vec4 start00; 
vec4 start10; 

vec4 start01; 
vec4 start11; 

vec4 end00; 
vec4 end10; 

vec4 end01; 
vec4 end11; 

float clipDist = 70; // Max distance
vec3 ambientMask = vec3(.15, .15, .15);

float EPSILON = .0001;
float minDist = EPSILON;

struct object{
	//MATERIAL
	// TODO: Refraction, texture
	vec4 color;
	float reflectivity;
	float specularity;

	//GENERAL
	int type;
	mat4 trans;
//} objectsi[5];
};


layout(std430, binding = 3) buffer bodies { object objects[]; };

shared struct light{
	bool directional;
	vec3 position;

} lights[1];

struct intersection{
	vec3 norm;
	vec3 coord;
	float distance;
};

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Transforms a point in space given matrix
vec3 transformPoint(vec3 vec, mat4 trans){
	vec4 vecTrans = vec4(vec.x, vec.y, vec.z, 1);
	return ((trans) * vecTrans).xyz;
}

// Transforms a "ray" in space given matrix (no translation applied)
vec3 transformRay(vec3 ray, mat4 trans){
	vec4 rayTrans = vec4(ray.x, ray.y, ray.z, 0);
	return (transpose(inverse((trans))) * rayTrans).xyz;
}


float intersectPlane( vec3 E){
	vec3 n  = normalize(vec3(0,1,0));
	//	return dot(E,n.xyz) + 1;
	return dot(E,n.xyz) + 1  + .01*sin(30*1*E.x)*sin(30*1*E.y)*sin(30*1*E.z);
}


float intersectSphere( vec3 E){
	return (length(E)-1.0f)+.02*sin(30*roll*E.x)*sin(30*roll*E.y)*sin(30*roll*E.z);
}

float intersectCylinder( vec3 E){
	float h =2;

	vec2 d = abs(vec2(length(E.xz),E.y)) - h;
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float intersectCone( vec3 E){
	vec3 c = vec3(3,1,3);
    vec2 q = vec2( length(E.xz), E.y );
    vec2 v = vec2( c.z*c.y/c.x, -c.z );
    vec2 w = v - q;
    vec2 vv = vec2( dot(v,v), v.x*v.x );
    vec2 qv = vec2( dot(v,w), v.x*w.x );
    vec2 d = max(qv,0.0)*qv/vv;
    return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
}
float intersectCube( vec3 E){
	vec3 b = vec3(1,1,1);
	vec3 d = abs(E) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float intersectDonut(vec3 E){
	vec2 t = vec2(1,0.5);
	vec2 q = vec2(length(E.xz)-t.x,E.y);
	return length(q)-t.y;

}
float intersectObject( vec3 E, int type){

	switch(type){
		case 1:
			return intersectSphere(E);
		case 2:
			return intersectPlane(E);
		case 3:
			return intersectCylinder(E);
		case 4:
			return intersectCone(E);
		case 5:
			return intersectCube(E);
		case 6:
			return intersectDonut(E);
	}
}

vec3 calcNormal(vec3 E, int type) {
    return normalize(vec3(
        intersectObject(vec3(E.x + EPSILON, E.y, E.z), type) - intersectObject(vec3(E.x - EPSILON, E.y, E.z), type),

        intersectObject(vec3(E.x, E.y + EPSILON, E.z), type) - intersectObject(vec3(E.x, E.y - EPSILON, E.z), type),
        intersectObject(vec3(E.x, E.y, E.z  + EPSILON), type) - intersectObject(vec3(E.x, E.y, E.z - EPSILON), type)
    ));
}

// change input of above functions and content to match ray marching

intersection nearestPoint(vec3 end, vec3 start, inout object closestObj){

	float closestDist = 1000000;
	closestObj.type = -1;
	intersection  closestIntersect;
	float minDepth = clipDist;


	for(int i=0; i< 5; i++){


		// Transform vectors in object's space to prep for testing
		vec3 E = transformPoint(start, inverse(objects[i].trans));
		vec3 D = transformPoint(end, inverse(objects[i].trans));

		float currPosDepth = 0;

		vec3 currPos = E + currPosDepth*normalize(D-E);
		vec3 finalPos = E;


		int j=0;
		while  ( j < 500 ){
			j++;

			currPos = E + currPosDepth*normalize(D-E);

			float dist = intersectObject(currPos, objects[i].type);

			if(dist < EPSILON*currPosDepth){

				finalPos = currPos;
				break;
			}

			if(currPosDepth > minDepth)
				break;

			currPosDepth += dist;
		}

		if(finalPos != E && currPosDepth < minDepth){
			//TODO apply min scale trans
			minDepth = currPosDepth; //will need to transform this to world along with comarison

			closestIntersect.coord  = finalPos;
			closestIntersect.norm = calcNormal(currPos, objects[i].type);
			closestObj = objects[i];

		}
	}


	return closestIntersect;
}


void main() {

	// CALCULATION OF RAY TO BE EVAULUATED
	invViewProjMat = inverse(proj * view);

	/* Calculate the positions of the bounds of this NDC space in
	world space */
	start00 =  invViewProjMat * vec4(-1.0, 1.0, -1.0, 1.0);
	start00.xyz /=  start00.w;

	start01 =  invViewProjMat * vec4(-1.0, 1.0, -1.0, 1.0);
	start01.xyz /=  start01.w;

	start10 =  invViewProjMat * vec4(1.0, -1.0, -1.0, 1.0);
	start10.xyz /=  start10.w;

	start11 = invViewProjMat * vec4(1.0, 1.0, -1.0, 1.0);

	start11.xyz /= start11.w;

	end00 =  invViewProjMat * vec4(-1.0, -1.0, 1.0, 1.0);
 
	end00.xyz /= end00.w;

	end01 =  invViewProjMat * vec4(-1.0, 1.0, 1.0, 1.0);
	end01.xyz /=  end01.w;

	end10 =  invViewProjMat * vec4(1.0, -1.0, 1.0, 1.0);
	end10.xyz /=  end10.w;

	end11 = invViewProjMat * vec4(1.0, 1.0, 1.0, 1.0);
	end11.xyz /=  end11.w;

	/* Calculate this local work group's ray by interpolating its x y position
	with the frustrum's bounds */
	ivec2 texPos = ivec2(gl_GlobalInvocationID.xy);
	vec2 pos =  texPos / vec2(gl_NumWorkGroups.xy*8);

	vec3 start = mix(mix(start00.xyz, start01.xyz, pos.y), mix(start10.xyz, start11.xyz, pos.y), pos.x).xyz;
	vec3 end = mix(mix(end00.xyz, end01.xyz, pos.y), mix(end10.xyz, end11.xyz, pos.y), pos.x).xyz;

	end = start + clipDist*normalize(end - start);

	mat4 trans1 = (transpose(mat4(1.0, 0.0, 0.0, 2.0, 
										  0.0, 1.0, 0.0, 0.5, 
										  0.0, 0.0, 1.0,  0.0,  
										  0.0, 0.0, 0.0,  1.0)));

	mat4 trans2 = (transpose(mat4(1.0, 0.0, 0.0, 0, 
										  0.0, 1.0, 0.0, 0.5, 
										  0.0, 0.0, 1.0,  0.0,  
										  0.0, 0.0, 0.0,  1.0)));

	mat4 trans3 = (transpose(mat4(1.0, 0.0, 0.0, 0.0, 
										  0.0, 1.0, 0.0, -1.0, 
										  0.0, 0.0, 1.0,  0.0,  
										  0.0, 0.0, 0.0,  1.0)));

	mat4 trans4 = (transpose(mat4(1.0, 0.0, 0.0, 0.0, 
										  0.0, 1.0, 0.0, 0.5, 
										  0.0, 0.0, 1.0,  2.0,  
										  0.0, 0.0, 0.0,  1.0)));

	mat4 trans5 = (transpose(mat4(1.0, 0.0, 0.0, 0.0, 
										  0.0, 1.0, 0.0, 0.5, 
										  0.0, 0.0, 1.0,  -2.0,  
										  0.0, 0.0, 0.0,  1.0)));
	/*

	objects[0].type =1;
	objects[0].trans =trans1;
	objects[0].color = vec4(0,0,1,1);
	objects[0].reflectivity = 1;
	objects[0].specularity = 1;

	objects[1].type =1;
	objects[1].trans =trans2;
	objects[1].color = vec4(0,0,1,1);
	objects[1].reflectivity = 1;
	objects[1].specularity = 0;

	objects[2].type =2;
	objects[2].trans =trans3;
	objects[2].color = vec4(1,0,0,1);
	objects[2].reflectivity = 1;
	objects[2].specularity = 1;

	objects[3].type =1;
	objects[3].trans =trans4;
	objects[3].color = vec4(0,0,1,1);
	objects[3].reflectivity = 1;
	objects[3].specularity = 1;

	objects[4].type =1;
	objects[4].trans =trans5;
	objects[4].color = vec4(0,0,1,1);
	objects[4].reflectivity = 1;
	objects[4].specularity = 0;
*/

	// Color sky
	imageStore(destTex, texPos, vec4(.22,.67,0.9,1));

	int currReflect = 0;
	int maxReflect = 8;

	vec3 lightRay=vec3(4,1,0);
	lights[0].directional= false;
	lights[0].position = lightRay;

	vec4 accumColor =vec4(0,0,0,1);

	/*
	object closestObj;
	closestObj.type = -1;
	*/
	intersection  closestIntersect;

	// reflec - spec - type - trans
	object closestObj = 
	object(vec4(0,0,0,0),0,0,-1,trans4 ); 

	vec3 currEnd = end;
	vec3 currStart = start;

	bool isDone = false;

	while(currReflect < maxReflect && !isDone){

		closestIntersect = nearestPoint(currEnd, currStart, closestObj);

		vec4 illum;   

		illum.w  = 1;


		if(closestObj.type != -1){

			// Test if under shadow
			object closestObjShadow=
			object(vec4(0,0,0,0),0,0,1,trans4 ); 

			intersection  closestIntersectShadow;

			vec3 E = transformPoint(closestIntersect.coord, (closestObj.trans));

			if(lights[0].directional)
				lightRay = normalize(lights[0].position - E);
			else
				lightRay = normalize(lights[0].position);

			vec3 D = E+ clipDist*lightRay;

			closestIntersectShadow = nearestPoint(D, E, closestObjShadow);

			// Variables for light calculation
			vec3 N = transformRay(closestIntersect.norm, closestObj.trans); 
			vec3 H =((-1*lightRay + normalize(E - currStart)))/length((-1*lightRay + normalize(E - currStart)));

			float spec; // shininess, specularity

			if(closestObjShadow.type == -1 ){
				illum.xyz = ambientMask + ((1 * (dot(lightRay, N))+0 ));
				spec = pow((1-dot(N, H))*.5, 64)*closestObj.specularity;
			}else{
				illum.xyz = ambientMask;
				spec = 0;
			}

			float attent = (lights[0].directional) ? (lights[0].position - E).length:1; // Light's decreasing brightness relative to distance
			illum = ((closestObj.color * illum ) + spec)/attent*1;

			if(closestObj.reflectivity >0){
				currEnd  = E + clipDist*(normalize(E - currStart) 
					-2*(dot(normalize(E  - currStart), closestIntersect.norm) * closestIntersect.norm)); // Calc reflect vector

				currStart =  E;
			}
		}
		else{
			illum = vec4(.22,.67,0.9,1);
			isDone = true;
		}

		accumColor += (currReflect < 1) ? illum : illum*.3/currReflect;
		currReflect++;
	}

	imageStore(destTex, texPos, accumColor);
}



