################################################################################
# Project:  Lib LZMA
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckStructHasMember)
include(CheckTypeSize)
include(TestBigEndian)

check_c_source_compiles("
    #define __EXTENSIONS__ 1
    int main ()
    {  return 0; }
    " DEFINE_EXTENSIONS)
    
if(DEFINE_EXTENSIONS)
  set(CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS} -D__EXTENSIONS__=1 -D_ALL_SOURCE=1 -D_DARWIN_C_SOURCE=1 -D_GNU_SOURCE=1 -D_POSIX_PTHREAD_SEMANTICS=1 -D_TANDEM_SOURCE=1)
  add_definitions(-D__EXTENSIONS__=1 -D_ALL_SOURCE=1 -D_DARWIN_C_SOURCE=1 -D_GNU_SOURCE=1 -D_POSIX_PTHREAD_SEMANTICS=1 -D_TANDEM_SOURCE=1)
endif()    

unset(DOUBLE_SLASH_IS_DISTINCT_ROOT)
unset(EILSEQ)

option ( ENABLE_EXTRA "Enable a few rarely used encodings" OFF)

set(gt_expression_test_code  "+ * ngettext (\"\", \"\", 0)")
#set(gt_expression_test_code  "")

check_c_source_compiles("
    #include <libintl.h>
    extern int _nl_msg_cat_cntr;
    extern int *_nl_domain_bindings;
    int main ()
    {
        bindtextdomain (\"\", \"\");
        return * gettext (\"\")${gt_expression_test_code} + _nl_msg_cat_cntr + *_nl_domain_bindings;
    }
    " ENABLE_NLS)
#option ( ENABLE_NLS "Translation of program messages to the user's native language is requested" OFF)    

option ( ENABLE_RELOCATABLE "The package shall run at any location in the file system" ON )

check_c_source_compiles("
    #include <stdlib.h> 
    #if defined __MACH__ && defined __APPLE__
    #include <mach/mach.h>
    #include <mach/mach_error.h>
    #include <mach/thread_status.h>
    #include <mach/exception.h>
    #include <mach/task.h>
    #include <pthread.h>
    static mach_port_t our_exception_port;
    static void * mach_exception_thread (void *arg)
    {
      struct {
        mach_msg_header_t head;
        mach_msg_body_t msgh_body;
        char data[1024];
      } msg;
      mach_msg_return_t retval;
      retval = mach_msg (&msg.head, MACH_RCV_MSG | MACH_RCV_LARGE, 0, sizeof (msg),
                         our_exception_port, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
      if (retval != MACH_MSG_SUCCESS)
        abort ();
      exit (1);
    }
    
    static void nocrash_init (void)
    {
      mach_port_t self = mach_task_self ();
      if (mach_port_allocate (self, MACH_PORT_RIGHT_RECEIVE, &our_exception_port) == KERN_SUCCESS) {
        if (mach_port_insert_right (self, our_exception_port, our_exception_port, MACH_MSG_TYPE_MAKE_SEND) == KERN_SUCCESS) {
          exception_mask_t mask = EXC_MASK_BAD_ACCESS;
          pthread_attr_t attr;
          pthread_t thread;
          if (pthread_attr_init (&attr) == 0
              && pthread_attr_setdetachstate (&attr, PTHREAD_CREATE_DETACHED) == 0
              && pthread_create (&thread, &attr, mach_exception_thread, NULL) == 0) {
            pthread_attr_destroy (&attr);
            task_set_exception_ports (self, mask, our_exception_port, EXCEPTION_DEFAULT, MACHINE_THREAD_STATE);
          }
        }
      }
    }
    #else
    #include <signal.h>
    static void exception_handler (int sig)
    {
      exit (1);
    }
    static void nocrash_init (void)
    {
    #ifdef SIGSEGV
      signal (SIGSEGV, exception_handler);
    #endif
    #ifdef SIGBUS
      signal (SIGBUS, exception_handler);
    #endif
    }
    #endif

    #include <stdlib.h>
    #include <string.h>

    int main ()
    {
        int result = 0;
        {
            char *name = realpath (\"conftest.a\", NULL);
            if (!(name && *name == '/'))
            result |= 1;
        }
        {
            char *name = realpath (\"conftest.b/../conftest.a\", NULL);
            if (name != NULL)
            result |= 2;
        }
        {
            char *name = realpath (\"conftest.a/\", NULL);
            if (name != NULL)
            result |= 4;
        }
        {
            char *name1 = realpath (\".\", NULL);
            char *name2 = realpath (\"conftest.d//./..\", NULL);
            if (strcmp (name1, name2) != 0)
            result |= 8;
        }
        return result;
    }
    " FUNC_REALPATH_WORKS)

# GNULIB settings
set ( GNULIB_CANONICALIZE_LGPL 1 )
set ( GNULIB_SIGPIPE 1 )
set ( GNULIB_STRERROR 1 )
set ( GNULIB_TEST_CANONICALIZE_FILE_NAME 1 )
set ( GNULIB_TEST_ENVIRON 1 )
set ( GNULIB_TEST_LSTAT 1 )
set ( GNULIB_TEST_READ 1 )
set ( GNULIB_TEST_READLINK 1 )
set ( GNULIB_TEST_REALPATH 1 )
set ( GNULIB_TEST_SIGPROCMASK 1 )
set ( GNULIB_TEST_STAT 1 )
set ( GNULIB_TEST_STRERROR 1 )

check_symbol_exists ( alloca "alloca.h" HAVE_ALLOCA )
check_include_files ( alloca.h HAVE_ALLOCA_H )

check_function_exists ( canonicalize_file_name HAVE_CANONICALIZE_FILE_NAME )

check_symbol_exists ( clearerr_unlocked "stdio.h" HAVE_DECL_CLEARERR_UNLOCKED )
check_symbol_exists ( feof_unlocked "stdio.h" HAVE_DECL_FEOF_UNLOCKED )
check_symbol_exists ( ferror_unlocked "stdio.h" HAVE_DECL_FERROR_UNLOCKED )
check_symbol_exists ( fflush_unlocked "stdio.h" HAVE_DECL_FFLUSH_UNLOCKED )
check_symbol_exists ( fgets_unlocked "stdio.h" HAVE_DECL_FGETS_UNLOCKED )
check_symbol_exists ( fputc_unlocked "stdio.h" HAVE_DECL_FPUTC_UNLOCKED )
check_symbol_exists ( fputs_unlocked "stdio.h" HAVE_DECL_FPUTS_UNLOCKED )
check_symbol_exists ( fread_unlocked "stdio.h" HAVE_DECL_FREAD_UNLOCKED )
check_symbol_exists ( fwrite_unlocked "stdio.h" HAVE_DECL_FWRITE_UNLOCKED )
check_symbol_exists ( getchar_unlocked "stdio.h" HAVE_DECL_GETCHAR_UNLOCKED )
check_symbol_exists ( getc_unlocked "stdio.h" HAVE_DECL_GETC_UNLOCKED )
check_symbol_exists ( program_invocation_name "errno.h;stdio.h" HAVE_DECL_PROGRAM_INVOCATION_NAME )
check_symbol_exists ( program_invocation_short_name "errno.h;stdio.h" HAVE_DECL_PROGRAM_INVOCATION_SHORT_NAME )
check_symbol_exists ( putchar_unlocked "stdio.h" HAVE_DECL_PUTCHAR_UNLOCKED )
check_symbol_exists ( putc_unlocked "stdio.h" HAVE_DECL_PUTC_UNLOCKED )
check_symbol_exists ( setenv "stdlib.h" HAVE_DECL_SETENV )
check_symbol_exists ( strerror_r "string.h" HAVE_DECL_STRERROR_R )
check_symbol_exists ( environ "unistd.h" HAVE_ENVIRON_DECL )
check_symbol_exists ( getcwd "unistd.h" HAVE_GETCWD )
check_symbol_exists ( getc_unlocked "stdio.h" HAVE_GETC_UNLOCKED )
check_symbol_exists ( nl_langinfo "langinfo.h" HAVE_LANGINFO_CODESET )

check_c_source_compiles("
    #include <stddef.h>
    #include <stdio.h>
    #include <time.h>
    #include <wchar.h>
    int main ()
    {
        mbstate_t x; 
        return sizeof x;
    }" HAVE_MBSTATE_T)

if(HAVE_MBSTATE_T)
    set(USE_MBSTATE_T 1)
else()
    set(USE_MBSTATE_T 0)
endif()

check_include_files ( dlfcn.h HAVE_DLFCN_H )

check_function_exists ( iconv HAVE_ICONV )

check_include_files ( inttypes.h HAVE_INTTYPES_H )

check_type_size ( "long long int" LONG_LONG_INT )
check_type_size ( "unsigned long long int" UNSIGNED_LONG_LONG_INT )
check_type_size ( _Bool _BOOL )

check_function_exists ( lstat HAVE_LSTAT )

check_include_files ( mach-o/dyld.h HAVE_MACH_O_DYLD_H )

check_function_exists ( mbrtowc HAVE_MBRTOWC )
check_function_exists ( mbsinit HAVE_MBSINIT )
check_function_exists ( memmove HAVE_MEMMOVE )
check_function_exists ( readlink HAVE_READLINK )
check_function_exists ( readlinkat HAVE_READLINKAT )

check_include_files ( search.h HAVE_SEARCH_H )

check_function_exists ( setenv HAVE_SETENV )
check_function_exists ( setlocale HAVE_SETLOCALE )
check_function_exists ( strerror_r HAVE_STRERROR_R )

check_include_files ( sys/param.h HAVE_SYS_PARAM_H )

check_function_exists ( tsearch HAVE_TSEARCH )

check_include_files ( unistd.h HAVE_UNISTD_H )

check_c_source_compiles("
    extern __attribute__((__visibility__(\"hidden\"))) int hiddenvar;
    extern __attribute__((__visibility__(\"default\"))) int exportedvar;
    extern __attribute__((__visibility__(\"hidden\"))) int hiddenfunc (void);
    extern __attribute__((__visibility__(\"default\"))) int exportedfunc (void);
    void dummyfunc (void) {}
    int main (){
      return 0;
    }    
    " HAVE_VISIBILITY)
    
if(NOT HAVE_VISIBILITY)
    set(HAVE_VISIBILITY 0)
endif()        
    
check_include_files ( wchar.h HAVE_WCHAR_H )
if(HAVE_WCHAR_H)
    set(HAVE_WCHAR_H 1)
    set(BROKEN_WCHAR_H 0)
else()
    set(HAVE_WCHAR_H 0)
    set(BROKEN_WCHAR_H 1)
endif()

check_type_size ( wchar_t WCHAR_T )    
if(HAVE_WCHAR_T)
    set(HAVE_WCHAR_T 1)
endif()

check_function_exists ( wcrtomb HAVE_WCRTOMB )

check_include_files ( winsock2.h HAVE_WINSOCK2_H )

check_function_exists ( _NSGetExecutablePath HAVE__NSGETEXECUTABLEPATH )

check_include_files ( xalloc.h HAVE_XMALLOC_H )
if(NOT HAVE_XMALLOC_H)
    add_definitions ( -DNO_XMALLOC )
endif()

set ( ICONV_CONST " " )

check_c_source_compiles("
    #if defined STDC_HEADERS || defined HAVE_STDLIB_H
    # include <stdlib.h>
    #else
    char *malloc ();
    #endif

    int main ()
    {
        return ! malloc (0);
    }
    " MALLOC_0_IS_NONNULL)

check_c_source_compiles("
    #include <unistd.h>
    int main ()
    {
        char buf[20];
        return readlink (\"conftest.lnk2/\", buf, sizeof buf) != -1;
    } " READLINK_TRAILING_SLASH_BUG)

check_c_source_compiles("
    #include <sys/stat.h>
    int main ()
    {
        struct stat st; 
        return stat (\".\", &st) != stat (\"./\", &st);
    }" REPLACE_FUNC_STAT_DIR)
    
check_c_source_compiles("
    #include <sys/stat.h>
    int main ()
    {
        int result = 0;
        struct stat st;
        if (!stat (\"conftest.tmp/\", &st))
            result |= 1;
        #if HAVE_LSTAT
        if (!stat (\"conftest.lnk/\", &st))
            result |= 2;
        #endif
        return result;
    }" REPLACE_FUNC_STAT_FILE)
    
check_c_source_compiles("
    #include <string.h>
    #include <errno.h>
    int main ()
    {
        int result = 0;
        char *str;
        errno = 0;
        str = strerror (0);
        if (!*str) result |= 1;
        if (errno) result |= 2;
        if (strstr (str, \"nknown\") || strstr (str, \"ndefined\"))
           result |= 4;
        return result;
    }" REPLACE_STRERROR_0)
    
check_c_source_runs("    
    #include <errno.h>
    #include <stdio.h>
    #include <stdlib.h>
    extern char *strerror_r ();
    int main ()
    {
        char buf[100];
        char x = *strerror_r (0, buf, sizeof buf);
	    return ! isalpha (x);
    }" STRERROR_R_CHAR_P)
    
    
set ( USE_UNLOCKED_IO 1 )

test_big_endian(WORDS_BIGENDIAN)
if(NOT WORDS_BIGENDIAN)
    set(WORDS_LITTLEENDIAN TRUE)
endif()

set(TEST_INLINES inline __inline__ __inline)
foreach(TEST_INLINE ${TEST_INLINES})
    check_c_source_compiles("
        #ifndef __cplusplus
        typedef int foo_t;
        static ${TEST_INLINE} foo_t static_foo () {return 0; }
        ${TEST_INLINE} foo_t foo () {return 0; }
        #endif
        " TEST_INLINE_OK)
    if(TEST_INLINE_OK)
        set(inline ${TEST_INLINE})
        break()
    endif()
endforeach()

check_type_size(size_t SIZE_T)   
check_type_size(ssize_t SSIZE_T) 

set(PACKAGE ${PROJECT_NAME})
set(PACKAGE_NAME "lib${PACKAGE}")
set(PACKAGE_VERSION ${VERSION})
set(PACKAGE_STRING "${PACKAGE_NAME} ${PACKAGE_VERSION}")

if(APPLE)
  set(DLL_VARIABLE "__declspec(export)")
elseif(WIN32)
  set(DLL_VARIABLE "__declspec(dllexport)")
elseif(HAVE_VISIBILITY)
  set(DLL_VARIABLE "__attribute__((__visibility__(\"default\")))")  
else()
  set(DLL_VARIABLE "__attribute__((dllexport))") 
endif()

configure_file(${CMAKE_MODULE_PATH}/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h IMMEDIATE @ONLY)
add_definitions(-DHAVE_CONFIG_H) 

configure_file ( include/iconv.h.build.in ${CMAKE_CURRENT_BINARY_DIR}/include/iconv.h IMMEDIATE @ONLY)
configure_file ( libcharset/include/libcharset.h.in ${CMAKE_CURRENT_BINARY_DIR}/include/libcharset.h IMMEDIATE @ONLY)
configure_file ( libcharset/include/localcharset.h.build.in ${CMAKE_CURRENT_BINARY_DIR}/include/localcharset.h IMMEDIATE @ONLY)
#configure_file ( srclib/uniwidth.in.h ${CMAKE_CURRENT_BINARY_DIR}/srclib/uniwidth.h IMMEDIATE @ONLY)
#configure_file ( srclib/unitypes.in.h ${CMAKE_CURRENT_BINARY_DIR}/srclib/unitypes.h IMMEDIATE @ONLY)

