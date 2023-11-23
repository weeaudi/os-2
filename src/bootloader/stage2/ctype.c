#include "ctype.h"

char toupper(char chr)
{
    return islower(chr) ? (chr - 'a' + 'A') : chr;
}
bool islower(char chr)
{
    return chr >= 'a' && chr <= 'z';
}
