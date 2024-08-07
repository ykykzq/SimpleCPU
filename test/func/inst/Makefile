obj_path = ../obj
EXP = 0

srcs = $(wildcard *.S)
raws = $(patsubst %.S, ${obj_path}/%.s, $(srcs))
objs = $(patsubst %.S, ${obj_path}/%.o, $(srcs))

libinst.a: $(obj_path)/libinst.a

$(obj_path)/libinst.a: $(objs)
	loongarch32r-linux-gnusf-ar -cr  $@ $?

$(raws):${obj_path}/%.s:%.S
	loongarch32r-linux-gnusf-gcc \
		-I../include -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000 -DGUEST -DEXP=$(EXP)\
		-S $^ > $@

$(objs):${obj_path}/%.o:${obj_path}/%.s %.S
	loongarch32r-linux-gnusf-as -mabi=ilp32 -o $@ $< 

clean:
	rm -rf ${objs} ${raws} ${obj_path}/libinst.a ${obj_path}/a.out
