#ifndef __SMALL_ALLOC__
#define __SMALL_ALLOC__

#ifdef __cplusplus
extern "C"{
#endif
	void* small_alloc(int size);
	void small_free(void* mem);

#ifdef __cplusplus
}
#endif

#endif