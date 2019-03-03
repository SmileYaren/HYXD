#ifndef __MY_TIMER_LIST_H__
#define __MY_TIMER_LIST_H__


#ifdef __cplusplus
extern "C" {
#endif
	// on_timer��һ���ص�����,��timer������ʱ�����;
	// udata: ���û������Զ�������ݽṹ;
	// on_timerִ�е�ʱ�� udata,���������udata;
	// after_sec: �����뿪ʼִ��;
	// repeat_count: ִ�ж��ٴ�, repeat_count == -1һֱִ��;
	//repeat_msec:����ÿ���೤ʱ��ִ��һ�Σ�
	// ����timer�ľ��;
	struct timer;
	struct timer*
	schedule_repeat(void(*on_timer)(void* udata),
	         void* udata,
			 int after_msec,
			 int repeat_count,
			 int repeat_msec);


	// ȡ�������timer;
	void
	cancel_timer(struct timer* t);

	struct timer*
	schedule_once(void(*on_timer)(void* udata),
	              void* udata,
				  int after_msec);



	void* get_timer_udata(struct timer* t);
#ifdef __cplusplus
}
#endif

#endif

