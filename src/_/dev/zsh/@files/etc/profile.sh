#!/bin/sh

# pathmunge <path> [ {before|after} [ remove [ add ] ] ]
pathmunge ()
{
   if [[ $3 = remove ]]; then
      export PATH
      PATH=$(echo ":$PATH:" | sed -e "s#:$1:#:#g" -e 's/^:*//' -e 's/:*$//')

      [[ $4 = add ]] || return 0
   fi

   case ":${PATH}:" in
   *:"$1":*) ;;
   *) if [ "$2" = "after" ] ; then
         PATH=$PATH:$1
      else
         PATH=$1:$PATH
      fi

      export PATH
      ;;
   esac
}

# classpathmunge <path> [ {before|after} [ remove [ add ] ] ]
classpathmunge ()
{
   if [[ $3 = remove ]]; then
      export CLASSPATH
      CLASSPATH=$(echo ":$CLASSPATH:" | sed -e "s#:$1:#:#g" -e 's/^:*//' -e 's/:*$//')

      [[ $4 = add ]] || return 0
   fi

   case ":${CLASSPATH}:" in
   *:"$1":*) ;;
   *) if [ "$2" = "after" ] ; then
         CLASSPATH=$CLASSPATH:$1
      else
         CLASSPATH=$1:$CLASSPATH
      fi

      export CLASSPATH
      ;;
    esac
}

# ldlibrarypathmunge <path> [ {before|after} [ remove [ add ] ] ]
ldlibrarypathmunge ()
{
   if [[ $3 = remove ]]; then
      export LD_LIBRARY_PATH
      LD_LIBRARY_PATH=$(echo ":$LD_LIBRARY_PATH:" | sed -e "s#:$1:#:#" -e 's/^:*//' -e 's/:*$//')

      [[ $4 = add ]] || return 0
   fi

   case ":${LD_LIBRARY_PATH}:" in
   *:"$1":*) ;;
   *) if [ "$2" = "after" ] ; then
         LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
      else
         LD_LIBRARY_PATH=$1:$LD_LIBRARY_PATH
      fi

      export LD_LIBRARY_PATH
      ;;
   esac
}

# manpathmunge <path> [ {before|after} [ remove [ add ] ] ]
manpathmunge ()
{
   if [[ $3 = remove ]]; then
      export MANPATH
      MANPATH=$(echo ":$MANPATH:" | sed -e "s#:$1:#:#" -e 's/^:*//' -e 's/:*$//')

      [[ $4 = add ]] || return 0
   fi

   case ":${MANPATH}:" in
   *:"$1":*) ;;
   *) if [ "$2" = "after" ] ; then
         MANPATH=$MANPATH:$1
      else
         MANPATH=$1:$MANPATH
      fi

      export MANPATH
      ;;
   esac
}
