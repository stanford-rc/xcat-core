#!/bin/awk -f
# IBM(c) 2007 EPL license http://www.eclipse.org/legal/epl-v10.html

BEGIN {
	xcatdhost = ARGV[1]
    xcatdport = ARGV[2]


	ns = "/inet/tcp/0/" ARGV[1] "/" xcatdport

	while(1) {
		if((ns |& getline) > 0)
			print $0 | "logger -t xcat"

		if($0 == "ready")
			print "next" |& ns
		if($0 == "done")
			break
	}

	close(ns)

	exit 0
}

