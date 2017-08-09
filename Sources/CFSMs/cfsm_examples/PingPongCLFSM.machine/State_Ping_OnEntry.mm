cout << state_name() << "\t"
     << machine_id() << "/" << number_of_machines()
     << ": " << static_cast<int>(fmod(static_cast<double>(current_time_in_microseconds() / 1000000.0L), 100)) << endl;
