__kernel void make_image(__global float4 *cellData,
                         int numCells,
                         __global float *positionData,
                         __global float *colorData,
                         float scale) {
    int gti = get_global_id(0);
    int x = positionData[gti * 3 + 0];
    int y = positionData[gti * 3 + 1];
    int z = positionData[gti * 3 + 2];
    
    float3 position;
    position.x = x;
    position.y = y;
    position.z = z;
    int nearbyCells = 0;
    for (int i = 0; i < numCells; ++i) {
        if (all(fabs(position - cellData[i].xyz) <= scale) && cellData[i].w != 0) {
            ++nearbyCells;
        }
    }
    float val = nearbyCells / pow(scale * 2, 3);
//    val = val > 0 ? 1 : 0;
    colorData[gti * 4 + 3] += val;
    if (colorData[gti * 4 + 3] > 1) {
        colorData[gti * 4 + 3] = 1;
    }
}