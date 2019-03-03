#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "uv.h"
#include "time_list.h"

#define my_malloc malloc
#define my_free free


struct timer {
	uv_timer_t uv_timer; // libuv timer handle
	void(*on_timer)(void* udata);
	void* udata;
	int repeat_count; // -1һֱѭ��;
};

static struct timer*
alloc_timer(void(*on_timer)(void* udata),
void* udata, int repeat_count) {
	struct timer* t = my_malloc(sizeof(struct timer));
	memset(t, 0, sizeof(struct timer));

	t->on_timer = on_timer;
	t->repeat_count = repeat_count;
	t->udata = udata;
	uv_timer_init(uv_default_loop(), &t->uv_timer);
	return t;
}

static void
free_timer(struct timer* t) {
	my_free(t);
}

static void
on_uv_timer(uv_timer_t* handle) {
	struct timer* t = handle->data;
	if (t->repeat_count < 0) { // ���ϵĴ���;
		t->on_timer(t->udata);
	}
	else {
		t->repeat_count--;
		t->on_timer(t->udata);
		if (t->repeat_count == 0) { // ����time����
			uv_timer_stop(&t->uv_timer); // ֹͣ���timer
			free_timer(t);
		}
	}

}

struct timer*
	schedule_repeat(void(*on_timer)(void* udata),
	void* udata,
	int after_msec,
	int repeat_count,
	int repeat_msec) {
	struct timer* t = alloc_timer(on_timer, udata, repeat_count);

	// ����һ��timer;
	t->uv_timer.data = t;
	uv_timer_start(&t->uv_timer, on_uv_timer, after_msec, repeat_msec);
	// end 
	return t;
}

void
cancel_timer(struct timer* t) {
	if (t->repeat_count == 0) { // ȫ��������ɣ�;
		return;
	}
	uv_timer_stop(&t->uv_timer);
	free_timer(t);
}

struct timer*
	schedule_once(void(*on_timer)(void* udata),
	void* udata,
	int after_msec) {
	return schedule_repeat(on_timer, udata, after_msec, 1, after_msec);
}


void*
get_timer_udata(struct timer* t) {
	return t->udata;
}