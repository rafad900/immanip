#include "immanip/immanip.h"

#include <stdio.h>

int main(void)
{
    const char *version = immanip_version();
    if (version == NULL || version[0] == '\0') {
        fprintf(stderr, "Library version is empty\n");
        return 1;
    }
    return 0;
}
