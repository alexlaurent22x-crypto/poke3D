using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
var files=Directory.GetFiles("Assets","*.cs",SearchOption.AllDirectories);int errors=0;
foreach(var file in files) {
 var tree=CSharpSyntaxTree.ParseText(File.ReadAllText(file),new CSharpParseOptions(LanguageVersion.CSharp9),file);
 foreach(var diagnostic in tree.GetDiagnostics().Where(d=>d.Severity==DiagnosticSeverity.Error)){Console.WriteLine(diagnostic);errors++;}
}
Console.WriteLine($"C# 9 syntax: {files.Length} files, {errors} errors. This does not compile or validate Unity APIs.");
return errors==0?0:1;
