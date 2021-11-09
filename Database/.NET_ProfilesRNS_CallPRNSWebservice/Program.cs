using System;

namespace ProfilesRNS_CallPRNSWebservice
{
    class Program
    {
        static void Main(string[] args)
        {
            //Server
            string server = GetArg(args, "-server");
            //DatabaseName
            string database = GetArg(args, "-database");

            //Username
            string username = GetArg(args, "-username");
            //Password
            string password = GetArg(args, "-password");
            //Job
            string job = GetArg(args, "-job");

            CallPRNSWebservice a = new CallPRNSWebservice(server, database, username, password, job);
            a.Run();
        }

        static string GetArg(string[] args, string arg)
        {
            for (int i = 0; i < args.Length - 1; i++)
            {
                if (arg.Equals(args[i])) return args[i + 1];
            }
            return null;
        }
    }
}
