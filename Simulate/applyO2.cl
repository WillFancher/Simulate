__kernel void applyO2(float upperThreshold,
                      float lowerThreshold,
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
    
    int adder = -1;
    
    for (int i = 0; i < numSources; ++i) {
        float3 sourcePoint = o2Sources[i].xyz;
        float dist = distance(thisPoint, sourcePoint);
        float intensity = o2Sources[i].w / (dist + 1);
        if (intensity >= lowerThreshold && intensity < upperThreshold && adder < 0) {
            adder = 0;
        } else if (intensity >= upperThreshold) {
            adder = 1;
            break; // can't get better than that
        }
    }
    
    val += adder;
    
    
    // Integrate
    if (cellStatus < 2 && val > 0) {
        cellStatus++;
    } else if (cellStatus > 0 && val < 0) {
        cellStatus--;
    }
    cells[gti].w = cellStatus;
}