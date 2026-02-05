#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h>
#include <unistd.h>

int
main(int argc, char **argv)
   {
   char path[1024];
   char *plimitString = getenv("PATH_LIMIT");
   int plimit;
   int length;

   if (argc == 1)
      getcwd(path, 1024);
   else
      strcpy(path, argv[1]);

   plimit = (plimitString == NULL) ? 80 : atoi(plimitString);

   if ((length = strlen(path)) <= plimit)
      printf("%s\n", path);
   else
      {
      if (index(path + (length - plimit + 3), '/') == NULL)
         printf("*%s\n", path + (length - plimit + 1));
      else
         printf("...%s\n", index(path + (length - plimit + 3), '/'));
      }

   return 0;
   }
