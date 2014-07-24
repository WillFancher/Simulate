__kernel void integration(__global float4 *cellData,
                          __global int *integrationData) {
    int gti = get_global_id(0);
    int val = cellData[gti].w;
    int integ = integrationData[gti];
    
    if (val < 2 && integ > 0) {
        val++;
    } else if (val > 0 && integ < 0) {
        val--;
    }
    cellData[gti].w = val;
}