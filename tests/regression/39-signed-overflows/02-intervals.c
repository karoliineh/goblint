// PARAM: --set sem.int.signed_overflow assume_none --enable ana.int.interval --disable ana.int.def_exc
#include <assert.h>

int main(void) {
    int x = 0;
    while(x != 42) {
        x++;
        __goblint_check(x >= 1);
    }

}
