{
    application, m8ball,
    [
        {vsn, "1.0.0"},
        {description, "Answer vital question"},
        {modules, [m8ball, m8vall_sup, m8ball_server]},
        {applications, [stdlib, kernel, crypto]},
        {registered, [m8ball, m8vall_sup, m8ball_server]},
        {mod, {m8ball, []}},
        {env,
            [
                {
                    answers,
                    {
                        <<"Да"/utf8>>,
                        <<"Нет"/utf8>>,
                        <<"Сомнительно"/utf8>>,
                        <<"Мне не нравится ваш тон"/utf8>>,
                        <<"Конечно"/utf8>>,
                        <<"Конечно нет"/utf8>>,
                        <<"*отходит медленно и убегает*"/utf8>>
                    }
                }
            ]
        }
    ]
}.
