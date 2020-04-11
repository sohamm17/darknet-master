
def main():
mport argparse
import pexpect
import time
import os
import subprocess

class BenchmarkError(Exception):
      pass

  def main():
        parser = argparse.ArgumentParser(
                    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
          parser.add_argument("-n", help="number of runs", type=int,
                                        default=100)
            parser.add_argument("--program", help="the main program to run")
              parser.add_argument("--background", help="the background program to run")
                parser.add_argument("--datafile", help="the file to output result",
                                              default="benchmark.csv")

                  args = parser.parse_args()
                    if not args.program:
                            raise BenchmarkError("No program given")
                          if not args.background:
                                  raise BenchmarkError("No background process given")
                                if args.n < 1:
                                        raise BenchrmarkError("n cannot be less than 1")

                                      total_endtoend = 0
                                        total_bodytime = 0
                                          total_sched_exec = 0
                                            total_until_sched = 0
                                              total_after_main = 0
                                                total_system_manage = 0

                                                  n = args.n

                                                    for i in (0, n):
                                                            childmain = pexpect.spawn(args.program, timeout=None)
                                                                childbg = pexpect.spawn(args.background, timeout=None)


                                                                    childmain.expect(r"End to end: (\d+)")
                                                                        endtoend = childmain.match.group(1)
                                                                            childmain.expect(r"Body execution: (\d+)")
                                                                                bodytime = childmain.match.group(1)
                                                                                    childmain.expect(r"Scheduled execution: (\d+)")
                                                                                        sched_exec = childmain.match.group(1)
                                                                                            childmain.expect(r"Till Schedule start: (\d+)")
                                                                                                until_sched = childmain.match.group(1)
                                                                                                    childmain.expect(r"After Main ends: (\d+)")
                                                                                                        after_main = childmain.match.group(1)
                                                                                                            childmain.expect(r"System Management: (\d+)")
                                                                                                                system_manage = childmain.match.group(1)
                                                                                                                    childmain.expect(pexpect.EOF)
                                                                                                                        childbg.expect(pexpect.EOF)
                                                                                                                            
                                                                                                                                total_endtoend += long(endtoend)
                                                                                                                                    total_bodytime += long(bodytime)
                                                                                                                                        total_sched_exec += long(sched_exec)
                                                                                                                                            total_until_sched += long(until_sched)
                                                                                                                                                total_after_main += long(after_main)
                                                                                                                                                    total_system_manage += long(system_manage)
                                                                                                                                                      
                                                                                                                                                        with open(args.datafile, "ab") as datafile:
                                                                                                                                                                datafile.write('{},{},{},{},{},{},{}\n'.format(n, total_endtoend / n, total_bodytime / n, total_sched_exec / n,
                                                                                                                                                                                   total_until_sched / n, total_after_main / n, total_system_manage / n))

                                                                                                                                                                  datafile.close()

                                                                                                                                                                  if __name__ == "__main__":
                                                                                                                                                                        main()


if __name__ == "__main__":
    main()
