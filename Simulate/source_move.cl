__kernel void source_move(int numSources,
                          __global float4 *sourceData,
                          int numCells,
                          __global float4 *cellData,
                          __global float4 *directionData) {
    int gti = get_global_id(0);
    int branchEndIndex = directionData[gti].w;
    float4 branchEnd = sourceData[branchEndIndex];
    
    float3 vec = 0;
    for (int i = 0; i < numSources; ++i) {
        if (i != branchEndIndex) {
            float4 otherSource = sourceData[i];
            
            float dist = distance(branchEnd.xyz, otherSource.xyz);
            float force = branchEnd.w * otherSource.w / dist;
            vec += force * normalize(sourceData[branchEndIndex].xyz - sourceData[i].xyz);
        }
    }
    vec = normalize(vec);
    directionData[gti].xyz = vec;
}