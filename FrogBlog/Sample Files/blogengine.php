
<?php
    
    //
    // FrogBlog blogging engine code
    //
    
    $page = 1;
    $pagesize = 10;
    if (isset($_GET['page']))
    {
        $page = $_GET['page'];
    }

    if (isset($_GET['article']))
    {
        $article = $_GET['article'];
        readfile("articles/$article");
        return;
    }
    
    // 0628531C-BC0A-405F-A029-E54EC6AEE334-2019-01-03 14:38:55-08:00
    function cmp($a, $b)
    {
        $a_part = substr($a,-25,25);
        $b_part = substr($b,-25,25);
        if ($a_part == $b_part)
        {
            return 0;
        }
        return ($a_part < $b_part) ? 1 : -1;
    }

    
      if ($handle = opendir('articles'))
      {
          $files = array();
          while ($files[] = readdir($handle));
          
          usort($files,"cmp");
          closedir($handle);
          
          $filecount = count($files) - 3; // . and ..
          $pages = ceil($filecount / $pagesize);
          $articlecount = 1;
          foreach ($files as $articlefile)
          {
               if ($articlefile != "." && $articlefile != "..")
               {
                   if ($articlecount >  (($page - 1) * $pagesize) && $articlecount <= ($page * $pagesize))
                   {
                      readfile("articles/$articlefile");
                      print "<br />\n";
                   }
                   $articlecount++;
               }
          }
          
          $prev = $page - 1;
          $next = $page + 1;
          print '<div class="nav">';
          if ($page > 1)
          {
              print '<a href="BLOGPATH_HERE?page=' . $prev . '" class="previous">&laquo;Previous</a>';
          }
          else
          {
             //print '<a class="noprevious">&laquo;Previous</a>';
          }
          
          if ($page < $pages)
          {
              print '<a href="BLOGPATH_HERE?page=' . $next . '" class = "next">Next&raquo;</a>';
          }
          else
          {
             //print '<a class = "nonext">Next&raquo;</a>';
          }
          print '</div>';
          print "<br />\n";
          print "<br />\n";
      }
      else
      {
           print "No Articles<br>\n";
      }
  ?>
