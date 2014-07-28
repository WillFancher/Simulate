__kernel void test(__global float *colorData, __global float *positionData, float t) {
    int gti = get_global_id(0);
    positionData[gti * 3 + 0] += fmod(t, 2) < 1 ? .0001 : fmod(t, 2) > 1 ? -.0001 : 0;
    colorData[gti * 4 + 3] = (sin(t) + 1.0) / 2.0;
}