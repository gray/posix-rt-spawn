#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <spawn.h>

/*
 * TODO:
 *     - use %SIG to set the signal mask
 *     - use %POSIX_RT_SPAWN::FLAGS to set the flags
 *     - use %POSIX_RT_SPAWN::FILE_ACTIONS to set the file actions
 */

MODULE = POSIX::RT::Spawn    PACKAGE = POSIX::RT::Spawn
