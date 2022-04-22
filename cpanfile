requires 'perl', '5.008000';

on test => sub {
    requires 'Test::More',       '0.88';
    requires 'Test::Deep',       '0';
    requires 'Test::More::UTF8', '0';
};

on 'develop' => sub {
};

on 'build' => sub {
    requires 'Test::Pod';
}
