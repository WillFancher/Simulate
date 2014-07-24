inline uint rand(ulong random) {
    ulong gti = get_global_id(0);
    ulong seed = random + gti;
    seed = (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1);
    uint result = seed >> 16;
    
    // do it twice because it wasn't good enough
    seed = result + gti;
    seed = (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1);
    result = seed >> 16;
    
    return result;
}

__kernel void proliferation(ulong random,
                                   float threshold,
                                   int numCells,
                                   __global float4 *cellData,
                                   __global float4 *buffer) {
    int gti = get_global_id(0);
    
    int index = 0;
    for (int i = 0; i < numCells; ++i) {
        if (cellData[i].w >=2) {
            ++index;
            if (index > gti) {
                index--;
                break;
            }
        }
    }
    
    
    float percent = (float)rand(random) / (float)4294967295;
    
    float4 newCell;
    if (cellData[index].w == 2 && percent > threshold) {
        float4 thisCell = cellData[index];
        newCell.x = thisCell.x - .01;
        newCell.y = thisCell.y - .01;
        newCell.z = thisCell.z - .01;
        newCell.w = 1;
    } else {
        newCell.x = 0;
        newCell.y = 0;
        newCell.z = 0;
        newCell.w = 0;
    }
    buffer[gti] = newCell;
}