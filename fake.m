//
//  fake.m
//  pyaide
//
//  Created by Huima on 2023/4/11.
//


extern void sys_icache_invalidate(char*, long);


void __clear_cache(void *begin, void *end) {
    sys_icache_invalidate((char*)begin, ((char *)end) - ((char *)begin));
}
