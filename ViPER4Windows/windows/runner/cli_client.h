#ifndef RUNNER_CLI_CLIENT_H_
#define RUNNER_CLI_CLIENT_H_

#include <string>
#include <vector>

bool IsCliInvocation(const std::vector<std::string> &args);

int RunCli(const std::vector<std::string> &args);

#endif
