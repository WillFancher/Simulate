__kernel void test(__global float *colorData, float t) {
    int gti = get_global_id(0);
    // Change blue color
    colorData[gti * 4 + 2] = (sin(t) + 1.0) / 2.0;
}