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
            vec += force * normalize(branchEnd.xyz - otherSource.xyz);
        }
    }
    
    for (int i = 0; i < numCells; ++i) {
        float4 cell = cellData[i];
        
        if (cell.w > 0) {
            float dist = distance(branchEnd.xyz, cell.xyz);
            float force = branchEnd.w * cell.w * 100 / dist;
            vec += force * normalize(cell.xyz - branchEnd.xyz);
        }
    }
    vec = normalize(vec);
    directionData[gti].xyz = vec;
}