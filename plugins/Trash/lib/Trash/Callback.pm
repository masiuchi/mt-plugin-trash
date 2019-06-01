package Trash::Callback;
use strict;
use warnings;

sub init_app {
    return unless UNIVERSAL::isa( MT->app, 'MT::App::CMS' );

    my $list_actions = MT->registry(qw( applications cms list_actions ));

    foreach my $class (qw( entry page )) {
        my $delete = $list_actions->{$class}{delete};
        $delete->{condition} = sub { MT->app->mode eq 'list_trash' };

        foreach my $key (
            qw( publish set_draft add_tags remove_tags open_batch_editor ))
        {
            my $condition = $list_actions->{$class}{$key}{condition};
            $list_actions->{$class}{$key}{condition} = sub {
                MT->app->mode eq 'list_trash' ? 0 : $condition->();
            };
        }

        my $system_filters = MT->registry( 'system_filters', $class );
        foreach my $key ( keys %$system_filters ) {
            $system_filters->{$key}{condition}
                = sub { MT->app->mode ne 'list_trash' };
        }
    }
}

sub pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    $load_options->{terms}{trash}
        = $app->mode eq 'filtered_list_trash' ? 1 : \'IS NULL';
}

sub tmpl_src_list_common {
    my ( $cb, $app, $tmpl_ref ) = @_;
    return unless $app->mode eq 'list_trash';
    if ( $MT::VERSION < 7 ) {
        $$tmpl_ref =~ s/filtered_list/filtered_list_trash/g;
    }
    $$tmpl_ref =~ s/<mt:if name="listing_footer_content">/<mt:if>/;
}

sub tmpl_param_list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return unless $app->mode eq 'list_trash';
    my $class_label_plural
        = $app->param('_type') eq 'page' ? 'Pages' : 'Entries';
    $param->{object_label_plural}
        = $app->component('Trash')->translate("$class_label_plural in Trash");
    if ( $MT::VERSION >= 7 ) {
        $param->{jq_js_include} ||= '';
        $param->{jq_js_include} .= <<'__TMPL__';
  ListClient.prototype.filteredList = function (args) {
    if (!args) {
      args = {};
    }
    var columns;
    if (Array.isArray(args.columns)) {
      columns = args.columns.join(',');
    } else {
      columns = args.columns;
    }
    var data = {
      __mode: 'filtered_list_trash',
      blog_id: this.siteId,
      columns: columns,
      datasource: this.datasource,
      items: JSON.stringify(args.filter.items),
      limit: args.limit,
      magic_token: this.magicToken,
      page: args.page,
      sort_by: args.sortBy,
      sort_order: args.sortOrder
    };
    if (args.filter.id && !args.noFilterId) {
      data.fid = args.filter.id;
    }
    this.sendRequest(args, data);
  };
__TMPL__
    }
}

sub tmpl_src_entry_list_header {
    my ( $cb, $app, $tmpl_ref ) = @_;

    my $pre = quotemeta <<'__END_OF_PRE__';
<mt:setvarblock name="system_msg" append="1">
    <div id="msg-container">
__END_OF_PRE__

    my $insert = <<'__END_OF_INSERT__';
    <mt:if name="request.restored">
        <mtapp:statusmsg
            id="restored"
            class="success"
            rebuild="$rebuild">
            <__trans_section component="trash">
            <mt:if name="object_type" eq="entry">
                <__trans phrase="This entry has been restored from the trash.">
            <mt:else>
                <__trans phrase="This page has been restored from the trash.">
            </mt:if>
            </__trans_section>
        </mtapp:statusmsg>
    </mt:if>
    <mt:if name="request.trashed">
        <mtapp:statusmsg
            id="restored"
            class="success"
            rebuild="$rebuild">
            <__trans_section component="trash">
            <mt:if name="object_type" eq="entry">
                <__trans phrase="This entry has moved to the trash.">
            <mt:else>
                <__trans phrase="This page has moved to the trash.">
            </mt:if>
            </__trans_section>
        </mtapp:statusmsg>
    </mt:if>
__END_OF_INSERT__

    $$tmpl_ref =~ s/($pre)/$1$insert/;
}

1;
