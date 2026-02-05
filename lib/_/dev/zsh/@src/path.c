/*
 * Description:   path -- display the list of directories that comprise the
 *        current search PATH for commands
 *
 *    path [arg...] -- display the "active" pathname of the
 *        command(s) named by arg(s)
 *
 *    path -a [arg...] -- display all pathnames of the command(s)
 *        named by arg(s)
 *
 *    path -d [arg...] -- display the "active" dirname (pathname
 *        excluding the command name component) of the command(s)
 *        named by arg(s)
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <grp.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

#define HT  '\011'

#ifndef TRUE
#define TRUE   1
#define FALSE  0
#endif

#define OTH_EXEC  (1 & st->st_mode)
#define GRP_EXEC  ((st->st_gid == getegid()) && (010 & st->st_mode))
#define OWN_EXEC  ((st->st_uid == geteuid()) && (0100 & st->st_mode))


int
main(argc, argv)
int   argc;
char  *argv[];
{

   char  *c;
   char  cmd[76];
   char  *cmdname = argv[0];
   char  *dir[128];
   char  *getenv();
   char  opt;
   char  *path;
   char  *strcat();
   char  *strcpy();
   char  *user;
   char  *x;

   int   allpaths = FALSE;
   int   dir_only = FALSE;
   int   i;
   int   newdir;
   int   not_done;
   int     status = 1;

   struct   stat  s, *st;
   struct  group  g, *gr;


   i = 0;

   user = getenv ("USER");

   if (NULL != (path = getenv ("PATH"))) {
       newdir = TRUE;
       for (c = path; *c != '\0'; c++) {
      switch (*c) {
      case ':':
      case ' ':
      case  HT:
          *c = '\0';
          newdir = TRUE;
          break;
      default:
          if (newdir) {
         dir[i++] = c;
         newdir = FALSE;
          }
      }
       }
   }
   dir[i] = NULL;

   if (argv[1] == NULL) {
       for (i = 0; dir[i] != NULL; i++)
           printf ("%s\n", dir[i]);
       exit (0);
   }

   while (NULL != *++argv) {
       if (('-' == *(c = *argv)) && c[1]) {
      while (*(++c)) {
          switch (*c)
          {
         case 'a':
             allpaths = TRUE; break;
         case 'd':
             dir_only = TRUE; break;
         default:
             fprintf (stderr,
                 "usage: %s [ -a -d ] file ...\n",
                 cmdname);
             exit (1);
          }
      }
       }
       else {
      argv--;
      break;
       }
   }

   st = &s;

   while (NULL != *++argv) {
       not_done = TRUE;
       while (not_done) {
      for (i = 0; not_done && NULL != dir[i]; i++) {
          strcpy (cmd, dir[i]);
          strcat (cmd, "/");
          strcat (cmd, *argv);
          if (0 == stat(cmd, st)) {
         if (st->st_mode & S_IFREG) {
             if (OTH_EXEC || GRP_EXEC || OWN_EXEC) {
            status = 0;
            if ( dir_only )
                printf ("%s\n", dir[i]);
            else
                printf ("%s\n", cmd);

                 if (! allpaths)
                not_done = FALSE;
             }
             else {
            while (not_done && NULL != (gr = getgrent())) {
                while (not_done && NULL !=
                  (x = *(gr->gr_mem++))) {
               if (0 == strcmp(x, user)) {
                   if((st->st_gid == gr->gr_gid &&
                     (010 & st->st_mode))) {
                  status = 0;
                  if ( dir_only )
                      printf ("%s\n", dir[i]);
                  else
                      printf ("%s\n", cmd);
                     if (! allpaths)
                     not_done = FALSE;
                   }
               }
                }
            }
             }
         }
          }
      }
      not_done = FALSE;
       }
   }

return(status);
}
