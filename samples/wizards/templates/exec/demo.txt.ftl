<#assign result = ProcessUtils.exec("C:/home/tools/Perl/bin/perl.exe", StringUtils.split("-v", " "))>
Process result:
exit code: ${result.exitCode()}
stdout: >>>${result.stdout()}<<<
stderr: >>>${result.stderr()}<<<
