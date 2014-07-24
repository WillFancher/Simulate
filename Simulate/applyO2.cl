__kernel void applyO2(float o2Threshold,
                      __global float4 *cells,
                      __global int *integratorData,
                      int numSources,
                      __global float4 *o2Sources)
{
    int gti = get_global_id(0);
    
    // applyO2 is the first integrator part run
    // Otherwise we'd set val to data[gti]
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
    integratorData[gti] = val;
}