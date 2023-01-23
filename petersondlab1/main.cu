#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cuda_runtime.h"
extern "C" {
  #include "timing.h"
}

typedef unsigned long long bignum;

__host__ int isPrime(bignum num);
__device__ int disPrime(bignum num);
void checkPrimes(char * result, bignum num, bignum n);
int totalPrimes(char * arr, int size);
__global__ void dCheckPrimes(char * result);

int main(int argc, char *argv[]) {
  // doubles used for time comp
  double now, then;
  double scost, pcost;

  bignum *h_n, *h_s =  (bignum *) malloc(sizeof(bignum));
  h_n = (bignum *) malloc(sizeof(bignum));
  *h_n = atoi(argv[1]);
  bignum blockSize;
  blockSize = atoi(argv[2]);
  char * result = (char *) malloc((*h_n + 1) *sizeof(int));
  char * d_result;

  // find primes using cpu and measure time below
  then = currentTime();
  checkPrimes(result, 0, *h_n);
  now = currentTime();
  scost = (now - then) * 1000;
  printf("time taken calculating primes using cpu: %lf ms\n", scost);
  int tempPrime = totalPrimes(result, (*h_n + 1));
  printf("Total primes found: %d\n", tempPrime);

  // find primes using gpu and measure time below
  then = currentTime();
  cudaMalloc((void**) &d_result, *h_n * sizeof(int));
  cudaMemcpy( d_result, result, *h_n * sizeof(int), cudaMemcpyHostToDevice);
  dCheckPrimes<<<ceil((*h_n+1)/2.0/blockSize),blockSize>>>( d_result);
  cudaMemcpy( result, d_result, *h_n * sizeof(int), cudaMemcpyDeviceToHost);
  now = currentTime();
  pcost = (now - then) * 1000;
  printf("time taken calculating primes using cuda: %lf ms\n", pcost);
  tempPrime = totalPrimes(result, (*h_n + 1));
  printf("Total primes found: %d\n", tempPrime);

  //free used memory
  cudaFree(d_result);
  free(result);
  free(h_n);
  free(h_s);
}

/*
  dCheckPrimes: kernal function used to start operations on the gpu using cuda

  result -> the array that the function will return the results too
*/
__global__ void dCheckPrimes(char * result) {
  // get thread id which will also map to postion in array
  int id = blockIdx.x*blockDim.x+threadIdx.x;

  // check if current value is 0 if so bump id to 2 (first prime)
  if (id == 0) { id += 2;}
  else { 
    // will cause threads to skip even positions in array
    id = id + id + 1;
  }
  result[id] = disPrime(id);
}

/*
  checkPrimes: function used to find primes in an array using the cpu

  result -> the array that the function will return the results too
  n -> number to check for prime up too
*/
void checkPrimes(char * result, bignum num, bignum n) {
  bignum i;

  // if num is even add 1 to make odd
  if(num % 2 == 0) { num++; }

  // go thorugh odd numbers checking if each is prime
  for(i=num; i<num+n; i = i+2) {
    result[i] = isPrime(i);
  }

}

/*
  isPrime: takes one integer and checks if integer is prime or not used by host

  num -> integer to check if prime
*/
__host__ int isPrime(bignum num) {
  
  bignum i;
  bignum lim = (bignum) sqrt(num) + 1;

  for(i = 2; i<lim; i++) {
    if(num % i == 0) {
      return 0;
    }
  }
  return 1;
}

/*
  disPrime: takes one integer and checks if integer is prime or not used by device

  num -> integer to check if prime
*/
__device__ int disPrime(bignum num) {

  bignum i;
  bignum lim = (bignum) sqrtf(num) + 1;

  for(i = 2; i<lim; i++) {
    if(num % i == 0) {
      return 0;
    }
  }
  return 1;
}

/*
  totalPrimes: function used to check for total amount of primes in array

  arr -> array filled with primes to count
  size -> size of array being passed in 
*/
int totalPrimes(char * arr, int size) {
  int j = 0;
  for(int i = 0; i < size; i++) {
    if(arr[i] == 1) {
      j++;
    }
  }

  return j;
}