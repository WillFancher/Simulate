__kernel void make_image(__global float4 *cellData,
                         int numCells,
                         write_only image3d_t image,
                         float scale) {
    int x = get_global_id(0);
    int y = get_global_id(1);
    int z = get_global_id(2);
    
    float3 position = (x,y,z);
    int nearbyCells = 0;
    for (int i = 0; i < numCells; ++i) {
        if (distance(position * scale, cellData[i].xyz) <= scale) {
            ++nearbyCells;
        }
    }
    float val = nearbyCells / (3.14159 * pow(scale, 3) * 4.0/3.0);
    write_imagef(image, (x,y,z,0), (1, 1, 1, val));
}