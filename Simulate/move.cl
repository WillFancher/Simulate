__kernel void move(int numIterations, int numCells,
                   __global float4 *cellData,
                   __global float4 *outData) {
    int gti = get_global_id(0);
    float3 thisPoint = cellData[gti].xyz;
    float3 vec = 0;
    for (int i = 0; i < numCells; ++i) if (i != gti) {
        float3 cellPoint = cellData[i].xyz;
        if (distance(thisPoint, cellPoint) < 1) {
            float3 distanceVec = thisPoint - cellPoint;
            vec += (normalize(distanceVec) - distanceVec) / (float)numIterations;
        }
    }
    
    thisPoint += vec;
    float4 outCell;
    outCell.xyz = thisPoint.xyz;
    outCell.w = cellData[gti].w;
    outData[gti] = outCell;
}