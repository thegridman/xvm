
const TextFileReporter(File file)
        extends BaseTextReporter
    {
    construct()
        {
        @Inject Directory curDir;
        construct TextFileReporter(curDir);
        }

    construct(Directory dir)
        {
        File file = dir.fileFor("test-results.txt");
        if (file.exists)
            {
            file.delete();
            }
        construct TextFileReporter(file.ensure());
        }

    private static Byte[] NewLine = "\n".utf8();

    @Override
    void printLine(String s)
        {
        file.append(s.utf8());
        file.append(NewLine);
        }
    }