#ifndef PACKAGE_H
#define PACKAGE_H

#include "../ast/ast.h"

void package_init(const char* name);

void package_paths(const char* paths);

ast_t* program_load(const char* path, int verbose);

ast_t* package_load(ast_t* from, const char* path, bool* init, int verbose);

void package_done();

#endif