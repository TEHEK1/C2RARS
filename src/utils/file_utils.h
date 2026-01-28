#ifndef FILE_UTILS_H
#define FILE_UTILS_H

#include <string>
#include <vector>

namespace c2rars {
namespace utils {
bool fileExists(const std::string& filename);

std::string readFile(const std::string& filename);

std::vector<std::string> readLines(const std::string& filename);

bool writeFile(const std::string& filename, const std::string& content);

std::string getFileExtension(const std::string& filename);

std::string getBaseName(const std::string& filename);

} // namespace utils
} // namespace c2rars

#endif // FILE_UTILS_H
