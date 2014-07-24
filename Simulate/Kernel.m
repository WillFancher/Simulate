#import "Kernel.h"

cl_ndrange makeRangeForKernel(void *kernel, int numWorkItems) {
//    size_t workgroup_size;
//    gcl_get_kernel_block_workgroup_info(kernel,
//                                        CL_KERNEL_WORK_GROUP_SIZE,
//                                        sizeof(workgroup_size), &workgroup_size, NULL);
//    if (workgroup_size > numWorkItems) {
//        workgroup_size = numWorkItems;
//    }
    cl_ndrange range = {
        1, // number of dimensions
        {0}, // offset for each dimension
        {numWorkItems}, // number of items in each dimension
        {0}
    };
    
    return range;
}