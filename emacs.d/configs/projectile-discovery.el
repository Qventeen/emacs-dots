;;(require 'projectile)
(defun q/projectile-discovery-project-recursive (project-dir)
  "Recursively searching projects in directory"
  (when (and (file-directory-p project-dir)
             (not (member (file-name-nondirectory project-dir) '(".." ".")))
	     (not (projectile-ignored-directory-p project-dir))
	     ;; (not (member project-dir projectile-known-projects)))
	     )
    
    (if (projectile-project-p project-dir)
	(projectile-add-known-project project-dir)
      (dolist (subdir (directory-files project-dir t))
	(q/projectile-discovery-project-recursive subdir)))))

(defun q/projectile-discover-projects-in-search-path-recursively ()
 "Recursively discover projects in projectile search path"
 (interactive)
 (projectile-cleanup-known-projects)
 (mapcar #'q/projectile-discovery-project-recursive
	  projectile-project-search-path))








