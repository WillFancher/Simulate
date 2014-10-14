__kernel void zero_image_alpha(__global float *colorData) {
    int gti = get_global_id(0);
    colorData[gti * 4 + 3] = 0;
}