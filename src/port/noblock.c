/*-------------------------------------------------------------------------
 *
 * noblock.c
 *	  set a file descriptor as blocking or non-blocking
 *
 * Portions Copyright (c) 1996-2025, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/port/noblock.c
 *
 *-------------------------------------------------------------------------
 */

#include "c.h"

#include <fcntl.h>
#if defined(__HAIKU__)
#include <sys/ioctl.h>
#endif


/*
 * Put socket into nonblock mode.
 * Returns true on success, false on failure.
 */
bool
pg_set_noblock(pgsocket sock)
{
#if defined(__HAIKU__)
	int			on = 1;
#endif
#if !defined(WIN32)
	int			flags;
#endif

#if defined(__HAIKU__)
	/*
	 * fcntl(O_NONBLOCK) is visible via F_GETFL, but recv()/send() on TCP and
	 * AF_UNIX sockets ignore it.  ioctl(FIONBIO) is the flag the network
	 * stack honors.  Keep the fcntl() update below so F_GETFL matches.
	 */
	if (ioctl(sock, FIONBIO, &on) == -1)
		return false;
#endif
#if !defined(WIN32)
	flags = fcntl(sock, F_GETFL);
	if (flags < 0)
		return false;
	if (fcntl(sock, F_SETFL, (flags | O_NONBLOCK)) == -1)
		return false;
	return true;
#else
	unsigned long ioctlsocket_ret = 1;

	/* Returns non-0 on failure, while fcntl() returns -1 on failure */
	return (ioctlsocket(sock, FIONBIO, &ioctlsocket_ret) == 0);
#endif
}

/*
 * Put socket into blocking mode.
 * Returns true on success, false on failure.
 */
bool
pg_set_block(pgsocket sock)
{
#if defined(__HAIKU__)
	int			on = 0;
#endif
#if !defined(WIN32)
	int			flags;
#endif

#if defined(__HAIKU__)
	if (ioctl(sock, FIONBIO, &on) == -1)
		return false;
#endif
#if !defined(WIN32)
	flags = fcntl(sock, F_GETFL);
	if (flags < 0)
		return false;
	if (fcntl(sock, F_SETFL, (flags & ~O_NONBLOCK)) == -1)
		return false;
	return true;
#else
	unsigned long ioctlsocket_ret = 0;

	/* Returns non-0 on failure, while fcntl() returns -1 on failure */
	return (ioctlsocket(sock, FIONBIO, &ioctlsocket_ret) == 0);
#endif
}
