__kernel void applyO2(float o2Threshold,
                      __global float4 *cells,
                      int numSources,
                      __global float4 *o2Sources)
{
    int gti = get_global_id(0);
    
    int cellStatus = cells[gti].w;
    
    if (cellStatus == 0) {
        return;
    }
    
    int val = 0;
    float3 thisPoint = cells[gti].xyz;
    
    int shouldAdd = 0;
    
    for (int i = 0; i < numSources; ++i) {
        float3 sourcePoint = o2Sources[i].xyz;
        float dist = distance(thisPoint, sourcePoint);
        float intensity = o2Sources[i].w / (dist + 1);
        shouldAdd = shouldAdd || intensity >= o2Threshold;
    }
    
    val += shouldAdd ? 1 : -1;
    
    
    // Integrate
    if (cellStatus < 2 && val > 0) {
        cellStatus++;
    } else if (cellStatus > 0 && val < 0) {
        cellStatus--;
    }
    cells[gti].w = cellStatus;
}