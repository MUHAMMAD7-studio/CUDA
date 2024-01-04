#include "timer.h"

timespec time_diff(timespec start, timespec end) {
    timespec diff;

    if ((end.tv_nsec - start.tv_nsec) < 0) {
        diff.tv_sec = end.tv_sec - start.tv_sec-1;
        diff.tv_nsec = 1000000000 + end.tv_nsec-start.tv_nsec;
    } else {
        diff.tv_sec = end.tv_sec - start.tv_sec;
        diff.tv_nsec = end.tv_nsec - start.tv_nsec;
    }

    return diff;
}