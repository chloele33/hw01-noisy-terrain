#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random1( vec2 p , vec2 seed) {
return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

// combine height with fbm 3D
float interpNoise3D(float x, float y, float z) {
    float intX = floor(x);
    float intY = floor(y);
    float intZ = floor(z);
    float fractX = fract(x);
    float fractY = fract(y);
    float fractZ = fract(z);

    float v1 = random1(vec3(intX, intY, intZ), vec3(1.0, 1.0, 1.0));
    float v2 = random1(vec3(intX, intY, intZ + 1.0), vec3(1.0, 1.0, 1.0));
    float v3 = random1(vec3(intX + 1.0, intY, intZ + 1.0), vec3(1.0, 1.0, 1.0));
    float v4 = random1(vec3(intX + 1.0, intY, intZ), vec3(1.0, 1.0, 1.0));
    float v5 = random1(vec3(intX, intY + 1.0, intZ), vec3(1.0, 1.0, 1.0));
    float v6 = random1(vec3(intX, intY + 1.0, intZ + 1.0), vec3(1.0, 1.0, 1.0));
    float v7 = random1(vec3(intX + 1.0, intY + 1.0, intZ), vec3(1.0, 1.0, 1.0));
    float v8 = random1(vec3(intX + 1.0, intY + 1.0, intZ + 1.0), vec3(1.0, 1.0, 1.0));


    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float i5 = mix(i1, i2, fractY);
    float i6 = mix(i3, i4, fractY);

    return mix(i5, i6, fractZ);
}

float fbm3d(float x, float y, float z) {
  float total = 0.f;
  float persistence = 0.5f;
  int octaves = 15;

  vec3 pos = vec3(x, y, z);

  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.0, float(i));
    float amp = pow(persistence, float(i));
    total += abs(interpNoise3D( pos.x / 80.0  * freq, pos.y / 10.0 * freq, pos.z / 20.0 * freq)) * amp;
  }
  return  total;
}

vec3 getColor(vec2 point, float height){
    vec3 deepWater = vec3(11.0 / 255.0, 62.0 / 255.0, 81.0 / 255.0);
    vec3 shallowWater = vec3(35.0 / 255.0, 99.0 / 255.0, 122.0 / 255.0);
    vec3 darkWater = vec3(6.0 / 255.0, 42.0 / 255.0, 76.0 / 255.0);
    vec3 rock = vec3(104.0 / 255.0, 92.0 / 255.0, 74.0 / 255.0);
    vec3 snow = vec3(1.0, 1.0, 1.0);
    vec3 grass = vec3(68.0 / 255.0, 100.0 / 255.0, 11.0 / 255.0);
    if (height > 5.0) {
        return snow;
    } else if (height > 3.8){
        if (random1(point, point) < 0.9) {
            // mix snow
            return mix(snow, rock, random1(point, point));
        } else {
            return rock;
        }
    } else if (height > 3.2){
              if (random1(point, vec2(1.0, 1.0)) < 0.2) {
                  // mix snow
                  return mix(snow, rock, random1(point, point));
              } else {
                  return rock;
              }
    } else if (height > 2.5) {
        return rock;
    } else if (height > 2.0) {
        return mix(rock, grass, random1(point, point));
    } else if (height > 0.5) {
        return grass;
    } else if (height < 0.05) {
    return darkWater;
    }

    if (height < 0.1) {
        return deepWater;
      }
      if (height < 0.2) {
        return shallowWater;
    } else {
        return vec3(0.0, 0.0, 0.0);
    }
}


void main()
{
    float t = clamp(smoothstep(15.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    vec2 pos = fs_Pos.xz + u_PlanePos;
    // combine height with fbm 3d to get color

    float heightNoise = clamp(pow(fbm3d(pos.x, pos.y, fs_Pos.y), 1.0), 0.0, 1.0) * 1.0;
    vec3 col = getColor(pos, fs_Pos.y * heightNoise);


    out_Col = vec4(mix(vec3(0.5 * (col + 1.0)), vec3(205.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);

}
