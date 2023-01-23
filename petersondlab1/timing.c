#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

// current time: will return the current time.    
double currentTime() {
  struct timeval now;
  gettimeofday(&now, NULL);

  return now.tv_sec + now.tv_usec/1000000.0;
}
